note
	description: "[
		The checks an Ask answer must pass before the window runs it (0.7.31, from
		NEEDLE's validator for its run 7): a model proposes tool calls; only calls
		whose every reference, number, version, word and query comes from what the
		reader typed are run. One failed call refuses the whole answer, and the
		window falls back to its search box with the reader's words; `refusal' says
		which rule failed, for the log.

		THE RULES (NEEDLE's numbering):
		 2 the tool is one of the eight, its argument keys are its own, the
		   required ones given;
		 3 a reference reads (BIB_REFERENCE_LINKER's forgiving face) to a book the
		   content holds;
		 4 every chapter and verse number in it was typed, as digits or words
		   (chapter 1 of a one-chapter book excepted: "Jude verse 9");
		 5-7 a version is a code the content holds; a version the reader named
		   in words wins ("Septuagint" LXX, "Greek" LXX in the Old Testament and WH
		   in the New); a version the program lacks (ESV, NIV ...) is refused; the
		   Hebrew text is the Old Testament's, WH, TR and Byz the New's;
		 8 a word to study, an English word or a lemma was typed, as a whole word;
		 9 a search query reads (BIB_QUERY_PARSER), its every word was typed, its
		   scope is a named scope;
		10 a query that kept the reader's words but lost a mark is mended: a
		   quoted run quoted, "any form of X" X*, "A or B" A OR B, "A but not B"
		   A NOT B, "the Greek word X" lemma:X;
		11 a request about the internet, the web, today's news or a weather
		   forecast is not Ask's (`is_outside': phrases, so "the good news" and
		   "fair weather" pass);
		12 each call is checked on its own.
		Rule 1 (a reference the box reads is opened without asking) is the
		window's, before it asks.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ASK_CHECK

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE)
			-- Checks against `a_bible''s books, versions, parser and scopes.
		do
			bible := a_bible
			create refusal.make_empty
		end

feature -- Access

	bible: SIMPLE_BIBLE

	refusal: STRING_32
			-- Which rule refused the last `checked' answer; empty when it passed.

feature -- Checking

	is_outside (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Rule 11: does `a_text' ask for the internet, the web, the news or the weather?
		do
			Result := across Outside_words as ic some has_word (a_text, ic) end
		end

	checked (a_text: READABLE_STRING_GENERAL; a_calls: LIST [BIB_ASK_CALL]): ARRAYED_LIST [BIB_ASK_CALL]
			-- `a_calls', mended where rule 10 mends, when every one passes every rule for the
			-- reader's words `a_text'; empty, `refusal' saying why, when any fails or there is none.
		do
			create refusal.make_empty
			create Result.make (a_calls.count)
			if is_outside (a_text) then
				refuse ("11", "the request is about the internet, the news or the weather")
			elseif a_calls.is_empty then
				refuse ("0", "no tool fits")
			else
				across a_calls as ic until not refusal.is_empty loop
					check_call (a_text, ic)
					if refusal.is_empty then
						Result.extend (ic)
					end
				end
			end
			if not refusal.is_empty then
				create Result.make (0)
			end
		ensure
			all_or_none: refusal.is_empty = not Result.is_empty
		end

feature {NONE} -- One call

	check_call (a_text: READABLE_STRING_GENERAL; a_call: BIB_ASK_CALL)
			-- Every rule for `a_call'; the first failure is `refusal'.
		local
			l_place: detachable TUPLE [book, chapter, verse: INTEGER]
		do
			if not Tools.has (a_call.name) then
				refuse ("2", {STRING_32} "no tool " + a_call.name)
			else
				across a_call.keys as ic until not refusal.is_empty loop
					if not across tool_keys (a_call.name) as al_key some al_key.same_string (ic) end then
						refuse ("2", {STRING_32} "the tool " + a_call.name + {STRING_32} " takes no " + ic)
					end
				end
				across required_keys (a_call.name) as ic until not refusal.is_empty loop
					if not a_call.has (ic) then
						refuse ("2", {STRING_32} "the tool " + a_call.name + {STRING_32} " needs " + ic)
					end
				end
			end
			if refusal.is_empty and then a_call.has ("reference") then
				l_place := place_of (a_call.text ("reference"))
				if l_place = Void then
					refuse ("3", {STRING_32} "the reference " + a_call.text ("reference") + {STRING_32} " does not read")
				elseif attached l_place then
					check_numbers (a_text, a_call.text ("reference"), l_place.book)
					if refusal.is_empty then
						check_versions (a_text, a_call, l_place.book)
					end
				end
			end
			if refusal.is_empty and then a_call.has ("word") then
				check_typed (a_text, a_call.text ("word"))
			end
			if refusal.is_empty and then a_call.has ("english") then
				check_typed (a_text, a_call.text ("english"))
			end
			if refusal.is_empty and then a_call.name.same_string ("search_text") then
				check_search (a_text, a_call)
			end
		end

	check_numbers (a_text, a_reference: READABLE_STRING_GENERAL; a_book: INTEGER)
			-- Rule 4: each chapter and verse number of `a_reference' (book `a_book') is in `a_text'.
		local
			l_numbers: ARRAYED_LIST [INTEGER]
			l_typed: ARRAYED_LIST [INTEGER]
			l_one_chapter: BOOLEAN
		do
			l_numbers := reference_numbers (a_reference)
			l_typed := numbers_in (a_text)
			l_one_chapter := bible.books.has_book (a_book) and then bible.books.is_single_chapter_book (a_book)
			across l_numbers as ic until not refusal.is_empty loop
				if not l_typed.has (ic) and then not (l_one_chapter and ic = 1 and @ic.cursor_index = 1 and l_numbers.count > 1) then
					refuse ("4", {STRING_32} "the number " + ic.out.to_string_32 + {STRING_32} " was not typed")
				end
			end
		end

	check_versions (a_text: READABLE_STRING_GENERAL; a_call: BIB_ASK_CALL; a_book: INTEGER)
			-- Rules 5-7 on the call's version and versions.
		local
			l_named: ARRAYED_LIST [STRING_8]
			l_list: ARRAYED_LIST [STRING_32]
			l_code: STRING_8
			i: INTEGER
		do
			if across Missing_versions as ic some has_word (a_text, ic) end then
				refuse ("5", "the version named is not in Simple Bible")
			else
				l_named := named_versions (a_text, a_book)
				if a_call.has ("version") then
					if not l_named.is_empty then
						a_call.set_text ("version", l_named.first)
					end
					check_version_code (a_call.text ("version").to_string_8, a_book)
				end
				if refusal.is_empty and then a_call.has ("versions") then
					create l_list.make (3)
					from i := 1 until i > a_call.texts ("versions").count loop
						l_code := a_call.texts ("versions").i_th (i).to_string_8
						if not bible.text_reader.has_version (l_code) and then i <= l_named.count then
								-- a version the model wrote that is no code: the reader's own word for it
							l_code := l_named.i_th (i)
						end
						l_list.extend (l_code.to_string_32)
						i := i + 1
					end
					across l_named as ic loop
						if not across l_list as al_v some al_v.same_string_general (ic) end then
							l_list.extend (ic.to_string_32)
						end
					end
					a_call.set_texts ("versions", l_list)
					across l_list as ic until not refusal.is_empty loop
						check_version_code (ic.to_string_8, a_book)
					end
				end
			end
		end

	check_version_code (a_code: STRING_8; a_book: INTEGER)
			-- Rules 5 and 7: `a_code' is a version the content holds, of the right testament.
		do
			if not bible.text_reader.has_version (a_code) then
				refuse ("5", {STRING_32} "no version " + a_code.to_string_32)
			elseif a_book <= {BIB_CANON}.Last_old_testament_book and then across New_testament_only as ic some ic.same_string (a_code) end then
				refuse ("7", a_code.to_string_32 + {STRING_32} " holds the New Testament only")
			elseif a_book > {BIB_CANON}.Last_old_testament_book and then across Old_testament_only as ic some ic.same_string (a_code) end then
				refuse ("7", a_code.to_string_32 + {STRING_32} " holds the Old Testament only")
			end
		end

	check_typed (a_text, a_word: READABLE_STRING_GENERAL)
			-- Rule 8: `a_word' (a Strong's number as typed) is a whole word, or words, of `a_text'.
		do
			if a_word.is_empty or else not has_word (a_text, a_word) then
				refuse ("8", {STRING_32} "the word " + a_word.to_string_32 + {STRING_32} " was not typed")
			end
		end

	check_search (a_text: READABLE_STRING_GENERAL; a_call: BIB_ASK_CALL)
			-- Rules 10 and 9: mend the query, then it reads, its every word was typed, its scope is a
			-- named scope.
		local
			l_query: BIB_QUERY
			l_word: STRING_32
		do
			a_call.set_text ("query", mended_query (a_text, a_call.text ("query")))
			l_query := bible.query_parser.parsed (a_call.text ("query"), bible.search_scopes.whole_bible (Default_version))
			if not l_query.is_valid then
				refuse ("9", {STRING_32} "the query does not read: " + l_query.error_message)
			else
				across 1 |..| l_query.clause_count as al_i until not refusal.is_empty loop
					if not l_query.clause (al_i).is_operator then
						l_word := l_query.clause (al_i).text.twin
						l_word.prune_all ('*')
						l_word.prune_all ('"')
						if l_word.starts_with ({STRING_32} "lemma:") then
							l_word.remove_head (6)
						end
						if not l_word.is_empty then
							check_typed (a_text, l_word)
						end
					end
				end
			end
			if refusal.is_empty and then a_call.has ("scope") and then not a_call.text ("scope").is_empty
				and then bible.search_scopes.scope_named (a_call.text ("scope"), Default_version) = Void
			then
				refuse ("9", {STRING_32} "no scope " + a_call.text ("scope"))
			end
		end

feature {NONE} -- Rule 10

	mended_query (a_text, a_query: READABLE_STRING_GENERAL): STRING_32
			-- `a_query' with the marks the reader's words `a_text' asked for and the model lost.
		local
			l_lower: STRING_32
			l_quoted: STRING_32
			i, j: INTEGER
		do
			create Result.make_from_string_general (a_query)
			l_lower := a_text.to_string_32.as_lower
				-- a quoted run in the request: quoted in the query
			i := a_text.to_string_32.index_of ('"', 1)
			if i > 0 then
				j := a_text.to_string_32.index_of ('"', i + 1)
				if j > i + 1 then
					l_quoted := a_text.to_string_32.substring (i + 1, j - 1)
					if Result.has_substring (l_quoted) and then not Result.has_substring ({STRING_32} "%"" + l_quoted + {STRING_32} "%"") then
						Result.replace_substring_all (l_quoted, {STRING_32} "%"" + l_quoted + {STRING_32} "%"")
					end
				end
			end
			across Result.split (' ') as ic loop
				if not ic.is_empty and then ic.is_valid_as_string_8 and then not ic.has ('*') and then not ic.has ('"') and then not ic.has (':') then
					if l_lower.has_substring ({STRING_32} "any form of " + ic.as_lower) or l_lower.has_substring ({STRING_32} "starting with " + ic.as_lower)
						or l_lower.has_substring (ic.as_lower + {STRING_32} " with any ending")
					then
						Result := replaced_word (Result, ic, ic + {STRING_32} "*")
					elseif l_lower.has_substring ({STRING_32} "greek word " + ic.as_lower) or l_lower.has_substring ({STRING_32} "hebrew word " + ic.as_lower) then
						Result := replaced_word (Result, ic, {STRING_32} "lemma:" + ic)
					end
				end
			end
			Result := joined_by (Result, l_lower, " or ", " OR ")
			Result := joined_by (Result, l_lower, " but not ", " NOT ")
				-- (scan 63: not "without": "faith without works" is a phrase, not a NOT)
		end

	joined_by (a_query, a_lower: STRING_32; a_spoken, a_operator: READABLE_STRING_GENERAL): STRING_32
			-- `a_query' with "A B" made "A<operator>B" where the request says "A<spoken>B".
		local
			l_words: LIST [STRING_32]
			i: INTEGER
		do
			Result := a_query
			l_words := a_query.split (' ')
			from i := 1 until i >= l_words.count loop
				if not l_words.i_th (i).is_empty and then not l_words.i_th (i + 1).is_empty
					and then has_word (a_lower, l_words.i_th (i).as_lower + a_spoken.to_string_32 + l_words.i_th (i + 1).as_lower)
				then
					Result.replace_substring_all (l_words.i_th (i) + {STRING_32} " " + l_words.i_th (i + 1), l_words.i_th (i) + a_operator.to_string_32 + l_words.i_th (i + 1))
				end
				i := i + 1
			end
		end

	replaced_word (a_query, a_word, a_by: STRING_32): STRING_32
			-- `a_query' with the whole word `a_word' read as `a_by'.
		local
			l_words: LIST [STRING_32]
		do
			create Result.make (a_query.count + 8)
			l_words := a_query.split (' ')
			across l_words as ic loop
				if not Result.is_empty then
					Result.append_character (' ')
				end
				if ic.same_string (a_word) then
					Result.append (a_by)
				else
					Result.append (ic)
				end
			end
		end

feature {NONE} -- Reading the request

	place_of (a_reference: READABLE_STRING_GENERAL): detachable TUPLE [book, chapter, verse: INTEGER]
			-- Rule 3: the place `a_reference' names, its book held; Void when it reads as none.
		do
			if not a_reference.is_empty and then attached (create {BIB_REFERENCE_LINKER}.make_forgiving (bible.books)).place_in (a_reference) as al_place
				and then bible.books.has_book (al_place.book)
			then
				Result := al_place
			end
		end

	reference_numbers (a_reference: READABLE_STRING_GENERAL): ARRAYED_LIST [INTEGER]
			-- The chapter and verse numbers written in `a_reference', in order (a book's own number,
			-- "1 Peter", left out).
		local
			l_text: STRING_32
			i, j: INTEGER
		do
			create Result.make (4)
			l_text := a_reference.to_string_32
			from i := 1 until i > l_text.count loop
				if l_text [i].is_digit then
					from j := i until j > l_text.count or else not l_text [j].is_digit loop
						j := j + 1
					end
					if not (i = 1 and then j <= l_text.count and then l_text [j] = ' ' and then j < l_text.count and then l_text [j + 1].is_alpha) then
						Result.extend (l_text.substring (i, j - 1).to_integer)
					end
					i := j
				else
					i := i + 1
				end
			end
		end

	numbers_in (a_text: READABLE_STRING_GENERAL): ARRAYED_LIST [INTEGER]
			-- Every number `a_text' writes, as digits or as words ("thirteen", "twenty-one",
			-- "twenty one").
		local
			l_words: ARRAYED_LIST [STRING_32]
			l_word: STRING_32
			l_value, l_tens: INTEGER
			i: INTEGER
		do
			create Result.make (4)
			l_words := words_of (a_text)
			from i := 1 until i > l_words.count loop
				l_word := l_words.i_th (i)
				if l_word.is_natural and then l_word.count <= 3 then
					Result.extend (l_word.to_integer)
				elseif l_word.has ('-') and then across l_word.split ('-') as al_part all al_part.is_natural and al_part.count <= 3 end then
						-- "28-30" typed as one word: both numbers (scan 63)
					across l_word.split ('-') as al_part loop
						Result.extend (al_part.to_integer)
					end
				else
					l_tens := 0
					if l_word.has ('-') and then attached number_word (l_word.substring (1, l_word.index_of ('-', 1) - 1)) as al_t
						and then attached number_word (l_word.substring (l_word.index_of ('-', 1) + 1, l_word.count)) as al_u
					then
						Result.extend (al_t + al_u)
					elseif attached number_word (l_word) as al_value then
						l_value := al_value
						if l_value >= 20 and then l_value \\ 10 = 0 and then i < l_words.count and then attached number_word (l_words.i_th (i + 1)) as al_next
							and then al_next < 10
						then
							Result.extend (l_value + al_next)
						end
						Result.extend (l_value)
					end
				end
				i := i + 1
			end
		end

	number_word (a_word: READABLE_STRING_GENERAL): detachable INTEGER_REF
			-- The number `a_word' spells (one to ninety); Void for none.
		local
			i: INTEGER
		do
			from i := Number_words.lower until i > Number_words.upper or Result /= Void loop
				if Number_words [i].same_string_general (a_word.to_string_32.as_lower) then
					Result := Number_values [i]
				end
				i := i + 1
			end
		end

	named_versions (a_text: READABLE_STRING_GENERAL; a_book: INTEGER): ARRAYED_LIST [STRING_8]
			-- Rules 6-7: the versions `a_text' names in words, in the order of the keyword table, each
			-- once ("Greek": LXX in the Old Testament, WH in the New).
		local
			l_code: STRING_8
		do
			create Result.make (2)
			Result.compare_objects
			across Version_words as ic loop
				if has_word (a_text, ic.words) then
					l_code := ic.code
					if l_code.same_string ("GREEK") then
						if a_book <= {BIB_CANON}.Last_old_testament_book then
							l_code := "LXX"
						else
							l_code := "WH"
						end
					end
					if not Result.has (l_code) then
						Result.extend (l_code)
					end
				end
			end
		end

	has_word (a_text, a_word: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_word' (one word or several) in `a_text' as whole words, any case (one rule with the
			-- window: BIB_WORD_CHARACTERS, scan 63)?
		do
			Result := word_characters.has_whole_word (a_text, a_word)
		end

	word_characters: BIB_WORD_CHARACTERS
			-- What a word is made of.
		once
			create Result
		end

	words_of (a_text: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- The words of `a_text', lowercase (a hyphen stays inside a word).
		local
			l_word: STRING_32
		do
			create Result.make (8)
			create l_word.make_empty
			across a_text.to_string_32.as_lower as ic loop
				if is_word_character (ic) or (ic = '-' and not l_word.is_empty) then
					l_word.append_character (ic)
				elseif not l_word.is_empty then
					Result.extend (l_word)
					create l_word.make_empty
				end
			end
			if not l_word.is_empty then
				Result.extend (l_word)
			end
		end

	is_word_character (a_character: CHARACTER_32): BOOLEAN
			-- Part of a word (BIB_WORD_CHARACTERS).
		do
			Result := word_characters.is_word_character (a_character)
		end

	refuse (a_rule, a_why: READABLE_STRING_GENERAL)
			-- The answer fails rule `a_rule': `a_why' (the first failure stands).
		do
			if refusal.is_empty then
				refusal := {STRING_32} "rule " + a_rule.to_string_32 + {STRING_32} ": " + a_why.to_string_32
			end
		ensure
			refused: not refusal.is_empty
		end

feature {NONE} -- Tables

	Tools: ARRAY [STRING_32]
			-- NEEDLE's eight tools (bible_tools.json, tools v4).
		once
			Result := <<{STRING_32} "open_passage", {STRING_32} "show_parallel", {STRING_32} "word_study", {STRING_32} "words_behind",
				{STRING_32} "cross_references", {STRING_32} "interlinear", {STRING_32} "commentary", {STRING_32} "search_text">>
			Result.compare_objects
		end

	tool_keys (a_tool: STRING_32): ARRAY [STRING_32]
			-- The argument keys tool `a_tool' takes.
		do
			if a_tool.same_string ("open_passage") then
				Result := <<{STRING_32} "reference", {STRING_32} "version">>
			elseif a_tool.same_string ("show_parallel") then
				Result := <<{STRING_32} "reference", {STRING_32} "versions">>
			elseif a_tool.same_string ("word_study") then
				Result := <<{STRING_32} "word">>
			elseif a_tool.same_string ("words_behind") then
				Result := <<{STRING_32} "english">>
			elseif a_tool.same_string ("search_text") then
				Result := <<{STRING_32} "query", {STRING_32} "scope">>
			else
				Result := <<{STRING_32} "reference">>
			end
		end

	required_keys (a_tool: STRING_32): ARRAY [STRING_32]
			-- The argument keys tool `a_tool' needs.
		do
			if a_tool.same_string ("show_parallel") then
				Result := <<{STRING_32} "reference", {STRING_32} "versions">>
			elseif a_tool.same_string ("search_text") then
				Result := <<{STRING_32} "query">>
			else
				Result := <<tool_keys (a_tool) [1]>>
			end
		end

	Version_words: ARRAY [TUPLE [words: STRING_32; code: STRING_8]]
			-- Rule 6: the reader's words for a version, and its code ("GREEK": by testament).
		once
			Result := <<[{STRING_32} "septuagint", "LXX"], [{STRING_32} "greek old testament", "LXX"], [{STRING_32} "leningrad", "WLC"],
				[{STRING_32} "westcott-hort", "WH"], [{STRING_32} "westcott hort", "WH"], [{STRING_32} "greek new testament", "WH"],
				[{STRING_32} "textus receptus", "TR"], [{STRING_32} "byzantine", "Byz"], [{STRING_32} "vulgate", "Vul"],
				[{STRING_32} "latin", "Vul"], [{STRING_32} "tyndale", "Tyn"], [{STRING_32} "wycliffe", "Wyc"], [{STRING_32} "king james", "KJV"],
				[{STRING_32} "berean", "BSB"], [{STRING_32} "american standard", "ASV"], [{STRING_32} "young's", "YLT"],
				[{STRING_32} "hebrew", "WLC"], [{STRING_32} "greek", "GREEK"]>>
		end

	Missing_versions: ARRAY [STRING_32]
			-- Versions readers name that Simple Bible does not hold.
		once
			Result := <<{STRING_32} "ESV", {STRING_32} "NIV", {STRING_32} "NASB", {STRING_32} "NKJV", {STRING_32} "NRSV", {STRING_32} "NLT",
				{STRING_32} "CSB", {STRING_32} "RSV", {STRING_32} "MSG", {STRING_32} "AMP">>
		end

	Old_testament_only: ARRAY [STRING_8]
		once
			Result := <<"WLC">>
		end

	New_testament_only: ARRAY [STRING_8]
		once
			Result := <<"WH", "TR", "Byz">>
		end

	Outside_words: ARRAY [STRING_32]
			-- Rule 11, as phrases (scan 63: "the good news", "fair weather" and a spider's "web" are
			-- Scripture's, never refused).
		once
			Result := <<{STRING_32} "internet", {STRING_32} "google", {STRING_32} "online", {STRING_32} "website", {STRING_32} "the web",
				{STRING_32} "web search", {STRING_32} "latest news", {STRING_32} "news today", {STRING_32} "today's news",
				{STRING_32} "weather forecast", {STRING_32} "today's weather", {STRING_32} "weather today">>
		end

	Number_words: ARRAY [STRING_32]
		once
			Result := <<{STRING_32} "one", {STRING_32} "two", {STRING_32} "three", {STRING_32} "four", {STRING_32} "five", {STRING_32} "six",
				{STRING_32} "seven", {STRING_32} "eight", {STRING_32} "nine", {STRING_32} "ten", {STRING_32} "eleven", {STRING_32} "twelve",
				{STRING_32} "thirteen", {STRING_32} "fourteen", {STRING_32} "fifteen", {STRING_32} "sixteen", {STRING_32} "seventeen",
				{STRING_32} "eighteen", {STRING_32} "nineteen", {STRING_32} "twenty", {STRING_32} "thirty", {STRING_32} "forty",
				{STRING_32} "fifty", {STRING_32} "sixty", {STRING_32} "seventy", {STRING_32} "eighty", {STRING_32} "ninety">>
		end

	Number_values: ARRAY [INTEGER_REF]
			-- `Number_words'' values, index for index.
		local
			l_values: ARRAY [INTEGER]
			i: INTEGER
		once
			l_values := <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 30, 40, 50, 60, 70, 80, 90>>
			create Result.make_filled (0, 1, l_values.count)
			from i := 1 until i > l_values.count loop
				Result [i] := l_values [i]
				i := i + 1
			end
		end

	Default_version: STRING_8 = "KJV"
			-- The version a query and a scope are read for.

invariant
	refusal_is_a_rule: not refusal.is_empty implies refusal.starts_with ({STRING_32} "rule ")

end
