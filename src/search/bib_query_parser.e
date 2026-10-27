note
	description: "[
		Query text to a clause tree or a positioned error (VR-03..05). The syntax
		(GUI spec P07): words; "exact phrases" ("a phrase"* ends in a prefix,
		word* is a prefix); AND, OR and NOT in capitals (words side by side mean
		AND); parentheses; strongs:H1254, or a bare H1254 or G5485; lemma: with a
		Hebrew or Greek headword or its plain letters (lemma:charis). OR binds
		loosest, then AND, then NOT; NOT takes away from what stands beside it,
		so a query cannot be NOT alone, nor NOT of a NOT. Every word and phrase
		must hold a letter or digit; at most `Max_terms' words, phrases and roots
		and `Max_depth' nested parentheses (design scan 48). morph: takes a Greek
		(V-AAI-3S) or Hebrew (Vqp3ms) code as the corpora write it, a final * for
		every code it begins (B05), searched in both corpora. Regular expressions
		are told as later work, at their position.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUERY_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Create a parser.
		do
			create tokens.make (8)
			create error_message.make_empty
			create strongs_check.make_from_text ("H1")
			create morph_check.make ({BIB_MORPH_CODE}.Every_scheme, "V")
			create scripts
			create unicode.make
		end

feature -- Parsing

	parsed (a_text: READABLE_STRING_GENERAL; a_scope: BIB_SEARCH_SCOPE): BIB_QUERY
			-- Clause tree of `a_text' over `a_scope'.
		require
			text_not_empty: not a_text.is_empty
		local
			l_root: detachable BIB_QUERY_NODE
			l_clauses: ARRAYED_LIST [BIB_QUERY_CLAUSE]
		do
			error_position := 0
			depth := 0
			create error_message.make_empty
			read_tokens (a_text)
			index := 1
			if error_position = 0 and tokens.is_empty then
				fail (1, "Type a word, a %"phrase%" or a Strong's number.")
			end
			if error_position = 0 then
				l_root := parsed_or
				if error_position = 0 and index <= tokens.count then
					fail (tokens.i_th (index).position, "This ')' has no '(' before it.")
				end
			end
			if error_position = 0 and attached l_root as al_root then
				check_negations (al_root, True)
			end
			if error_position = 0 and attached l_root as al_root then
				create l_clauses.make (8)
				al_root.flatten_into (l_clauses)
				create Result.make_valid (a_text, l_clauses, a_scope)
			else
				create Result.make_invalid (a_text, error_position.max (1).min (a_text.count + 1), error_message, a_scope)
			end
		ensure
			text_kept: Result.text.same_string_general (a_text) or not Result.is_valid
			scope_kept: Result.scope = a_scope
			error_located: not Result.is_valid implies (Result.error_position >= 1 and Result.error_position <= a_text.count + 1)
		end

feature {NONE} -- Tokens

	tokens: ARRAYED_LIST [TUPLE [kind: INTEGER; text: STRING_32; position: INTEGER]]
			-- The query's tokens, read by `read_tokens'.

	index: INTEGER
			-- The next token to parse.

	error_position: INTEGER
	error_message: STRING_32
			-- The first error found (position 0: none).

	strongs_check: BIB_STRONGS_KEY
			-- Answers `is_strongs_text'.

	morph_check: BIB_MORPH_CODE
			-- Answers `is_code_text'.

	scripts: BIB_SCRIPT_CLASSIFIER

	unicode: SIMPLE_UNICODE
			-- Tells a letter or digit, so a word with nothing to search is refused.

	depth: INTEGER
			-- How many parentheses enclose the token being parsed.

	Max_depth: INTEGER = 16
	Max_terms: INTEGER = 32
			-- Bounds on a query (the parser and the search recurse by depth, and each word is one
			-- index query).

	is_searchable (a_text: READABLE_STRING_32): BOOLEAN
			-- Does `a_text' hold a letter or a digit?
		do
			Result := across a_text as ic some unicode.is_letter_or_digit (ic) end
		end

	Token_word, Token_phrase, Token_open, Token_close, Token_and, Token_or, Token_not, Token_strongs, Token_lemma, Token_morph, Token_form: INTEGER = unique
			-- Token kinds.

	read_tokens (a_text: READABLE_STRING_GENERAL)
			-- Split `a_text' into `tokens', or `fail' at the first thing that cannot be a token.
		local
			l_text, l_word, l_lower, l_rest: STRING_32
			i, j: INTEGER
			c: CHARACTER_32
		do
			tokens.wipe_out
			l_text := a_text.to_string_32
			from i := 1 until i > l_text.count or error_position > 0 loop
				c := l_text [i]
				if c.is_space then
					i := i + 1
				elseif c = '(' then
					tokens.extend ([Token_open, {STRING_32} "(", i])
					i := i + 1
				elseif c = ')' then
					tokens.extend ([Token_close, {STRING_32} ")", i])
					i := i + 1
				elseif c = '"' then
					j := l_text.index_of ('"', i + 1)
					if j = 0 then
						fail (i, "This quotation mark has no closing one.")
					else
						l_word := l_text.substring (i, j)
						if j < l_text.count and then l_text [j + 1] = '*' then
							l_word.append_character ('*')
							j := j + 1
						end
						if not is_searchable (l_text.substring (i + 1, (l_text.index_of ('"', i + 1) - 1).max (i))) then
							fail (i, "This phrase has nothing to search for: it needs a letter or a digit.")
						else
							tokens.extend ([Token_phrase, l_word, i])
						end
						i := j + 1
					end
				else
					from j := i until j > l_text.count or else (l_text [j].is_space or l_text [j] = '(' or l_text [j] = ')' or l_text [j] = '"') loop
						j := j + 1
					end
					l_word := l_text.substring (i, j - 1)
					l_lower := l_word.as_lower
					if l_word.same_string ({STRING_32} "AND") then
						tokens.extend ([Token_and, l_word, i])
					elseif l_word.same_string ({STRING_32} "OR") then
						tokens.extend ([Token_or, l_word, i])
					elseif l_word.same_string ({STRING_32} "NOT") then
						tokens.extend ([Token_not, l_word, i])
					elseif l_word [1] = '/' then
						fail (i, "Regular expressions (/.../) come in a later release.")
					elseif l_word.has ('@') then
							-- A root in a form on one word: G3056@N-NSM.
						if not attached form_root (l_word.substring (1, l_word.index_of ('@', 1) - 1)) then
							fail (i, "Before @ write a root: a Strong's number such as G3056, or lemma:logos.")
						elseif not morph_check.is_code_text (form_code_text (l_word)) then
							fail (i, "After @ write a grammar code such as N-NSM or Vq*.")
						else
							tokens.extend ([Token_form, l_word, i])
						end
					elseif l_lower.starts_with ({STRING_32} "morph:") then
						l_rest := l_word.substring (7, l_word.count)
						if morph_check.is_code_text (l_rest) then
							tokens.extend ([Token_morph, l_rest, i])
						else
							fail (i, "morph: needs a code such as V-AAI-3S (Greek) or Vqp3ms (Hebrew); end it in * for every code it begins.")
						end
					elseif l_lower.starts_with ({STRING_32} "strongs:") then
						l_rest := l_word.substring (9, l_word.count)
						if not l_rest.is_empty then
							l_rest [1] := l_rest [1].as_upper
						end
						if strongs_check.is_strongs_text (l_rest) then
							tokens.extend ([Token_strongs, l_rest, i])
						else
							fail (i, "strongs: needs a number such as H1254 or G5485.")
						end
					elseif l_lower.starts_with ({STRING_32} "lemma:") then
						l_rest := l_word.substring (7, l_word.count)
						if l_rest.is_empty then
							fail (i, "lemma: needs a Hebrew or Greek headword, or its plain letters (lemma:charis).")
						else
							tokens.extend ([Token_lemma, l_rest, i])
						end
					elseif strongs_check.is_strongs_text (l_word) then
						tokens.extend ([Token_strongs, l_word, i])
					elseif is_searchable (l_word) then
						tokens.extend ([Token_word, l_word, i])
					else
						fail (i, "This word has nothing to search for: it needs a letter or a digit.")
					end
					i := j
				end
			end
			if error_position = 0 then
				check_width
			end
		end

	check_width
			-- At most `Max_terms' words, phrases and roots.
		local
			l_terms: INTEGER
		do
			across tokens as ic until error_position > 0 loop
				if ic.kind = Token_word or ic.kind = Token_phrase or ic.kind = Token_strongs or ic.kind = Token_lemma or ic.kind = Token_morph or ic.kind = Token_form then
					l_terms := l_terms + 1
					if l_terms > Max_terms then
						fail (ic.position, {STRING_32} "A search holds at most " + Max_terms.out + {STRING_32} " words, phrases and root words.")
					end
				end
			end
		end

feature {NONE} -- Grammar

	parsed_or: detachable BIB_QUERY_NODE
			-- or := and ("OR" and)*
		local
			l_operands: ARRAYED_LIST [BIB_QUERY_NODE]
			l_start: INTEGER
		do
			l_start := start_position
			create l_operands.make (2)
			if attached parsed_and as al_first then
				l_operands.extend (al_first)
			end
			from until error_position > 0 or index > tokens.count or else tokens.i_th (index).kind /= Token_or loop
				index := index + 1
				if attached parsed_and as al_next then
					l_operands.extend (al_next)
				end
			end
			if error_position = 0 then
				Result := combined ({BIB_QUERY_CLAUSE}.Or_clause, l_operands, l_start)
			end
		end

	parsed_and: detachable BIB_QUERY_NODE
			-- and := unary (["AND"] unary)*, side by side meaning AND.
		local
			l_operands: ARRAYED_LIST [BIB_QUERY_NODE]
			l_start: INTEGER
		do
			l_start := start_position
			create l_operands.make (2)
			if attached parsed_unary as al_first then
				l_operands.extend (al_first)
			end
			from until error_position > 0 or index > tokens.count or else (tokens.i_th (index).kind = Token_or or tokens.i_th (index).kind = Token_close) loop
				if tokens.i_th (index).kind = Token_and then
					index := index + 1
				end
				if attached parsed_unary as al_next then
					l_operands.extend (al_next)
				end
			end
			if error_position = 0 then
				Result := combined ({BIB_QUERY_CLAUSE}.And_clause, l_operands, l_start)
			end
		end

	parsed_unary: detachable BIB_QUERY_NODE
			-- unary := "NOT" primary | primary
		local
			l_operand: ARRAYED_LIST [BIB_QUERY_NODE]
			l_start: INTEGER
		do
			if index <= tokens.count and then tokens.i_th (index).kind = Token_not then
				l_start := tokens.i_th (index).position
				index := index + 1
				if attached parsed_primary as al_primary then
					create l_operand.make (1)
					l_operand.extend (al_primary)
					create Result.make_operator ({BIB_QUERY_CLAUSE}.Not_clause, l_operand, l_start)
				end
			else
				Result := parsed_primary
			end
		end

	parsed_primary: detachable BIB_QUERY_NODE
			-- primary := "(" or ")" | word | phrase | key
		local
			l_token: TUPLE [kind: INTEGER; text: STRING_32; position: INTEGER]
		do
			if index > tokens.count then
				if tokens.is_empty then
					fail (1, "Type a word, a %"phrase%" or a Strong's number.")
				else
					fail (tokens.last.position + tokens.last.text.count, {STRING_32} "Something must follow " + tokens.last.text + {STRING_32} ".")
				end
			else
				l_token := tokens.i_th (index)
				index := index + 1
				inspect l_token.kind
				when Token_open then
					if index <= tokens.count and then tokens.i_th (index).kind = Token_close then
						fail (l_token.position, "These parentheses are empty.")
					elseif depth >= Max_depth then
						fail (l_token.position, {STRING_32} "Parentheses nest at most " + Max_depth.out + {STRING_32} " deep.")
					else
						depth := depth + 1
						Result := parsed_or
						depth := depth - 1
						if error_position = 0 then
							if index <= tokens.count and then tokens.i_th (index).kind = Token_close then
								index := index + 1
							else
								fail (l_token.position, "This '(' has no ')' after it.")
							end
						end
					end
				when Token_close then
					fail (l_token.position, "This ')' has no '(' before it.")
				when Token_and, Token_or then
					fail (l_token.position, {STRING_32} "Put a word before " + l_token.text + {STRING_32} ".")
				when Token_not then
					fail (l_token.position, "NOT NOT says nothing: write one NOT.")
				when Token_word then
					create Result.make_leaf (create {BIB_QUERY_CLAUSE}.make_text ({BIB_QUERY_CLAUSE}.Word, l_token.text), l_token.position)
				when Token_phrase then
					create Result.make_leaf (create {BIB_QUERY_CLAUSE}.make_text ({BIB_QUERY_CLAUSE}.Phrase, l_token.text), l_token.position)
				when Token_strongs then
					create Result.make_leaf (create {BIB_QUERY_CLAUSE}.make_key ({BIB_QUERY_CLAUSE}.Strongs, create {BIB_STRONGS_KEY}.make_from_text (l_token.text)), l_token.position)
				when Token_lemma then
					create Result.make_leaf (create {BIB_QUERY_CLAUSE}.make_key ({BIB_QUERY_CLAUSE}.Lemma, create {BIB_LEMMA_KEY}.make (lemma_language (l_token.text), l_token.text)), l_token.position)
				when Token_form then
					if attached form_root (l_token.text.substring (1, l_token.text.index_of ('@', 1) - 1)) as al_root then
						create Result.make_leaf (create {BIB_QUERY_CLAUSE}.make_key ({BIB_QUERY_CLAUSE}.Form, create {BIB_FORM_KEY}.make (al_root, create {BIB_MORPH_CODE}.make ({BIB_MORPH_CODE}.Every_scheme, form_code_text (l_token.text)))), l_token.position)
					end
				when Token_morph then
					create Result.make_leaf (create {BIB_QUERY_CLAUSE}.make_key ({BIB_QUERY_CLAUSE}.Morph, create {BIB_MORPH_CODE}.make ({BIB_MORPH_CODE}.Every_scheme, l_token.text)), l_token.position)
				else
					fail (l_token.position, "This cannot be read.")
				end
			end
		end

	combined (a_kind: INTEGER; a_operands: ARRAYED_LIST [BIB_QUERY_NODE]; a_position: INTEGER): detachable BIB_QUERY_NODE
			-- The one operand, or an `a_kind' node over several starting at `a_position'; Void when
			-- there is none.
		do
			if a_operands.count = 1 then
				Result := a_operands.first
			elseif a_operands.count > 1 then
				create Result.make_operator (a_kind, a_operands, a_position.max (1))
			end
		end

	start_position: INTEGER
			-- Where the next token starts (1 at the end of the query).
		do
			if index <= tokens.count then
				Result := tokens.i_th (index).position
			else
				Result := 1
			end
		end

	check_negations (a_node: BIB_QUERY_NODE; a_stands_alone: BOOLEAN)
			-- A NOT must take away from something beside it: never the whole query, an OR's branch,
			-- the operand of another NOT, or an AND made only of NOTs. The error points at the NOT.
		do
			if a_node.is_negation and a_stands_alone then
				fail (a_node.position, "NOT needs something to take away from: write grace NOT law.")
			elseif a_node.is_negation then
					-- Design scan 48: NOT (NOT law) passed here and failed later without a place.
				across a_node.children as ic loop
					check_negations (ic, True)
				end
			elseif a_node.kind = {BIB_QUERY_CLAUSE}.And_clause then
				if across a_node.children as ic all ic.is_negation end then
					fail (a_node.children.first.position, "NOT needs something to take away from: write grace NOT law.")
				end
				across a_node.children as ic loop
					check_negations (ic, False)
				end
			else
				across a_node.children as ic loop
					check_negations (ic, a_node.kind = {BIB_QUERY_CLAUSE}.Or_clause)
				end
			end
		end

	form_root (a_text: STRING_32): detachable BIB_KEY
			-- The root before a form's @: strongs:G3056, a bare G3056, or lemma:logos; Void when none.
		local
			l_rest: STRING_32
		do
			if a_text.as_lower.starts_with ({STRING_32} "strongs:") then
				l_rest := a_text.substring (9, a_text.count)
				if not l_rest.is_empty then
					l_rest [1] := l_rest [1].as_upper
				end
			else
				l_rest := a_text.twin
			end
			if a_text.as_lower.starts_with ({STRING_32} "lemma:") then
				if a_text.count > 6 then
					create {BIB_LEMMA_KEY} Result.make (lemma_language (a_text.substring (7, a_text.count)), a_text.substring (7, a_text.count))
				end
			elseif strongs_check.is_strongs_text (l_rest) then
				create {BIB_STRONGS_KEY} Result.make_from_text (l_rest)
			end
		end

	form_code_text (a_word: STRING_32): STRING_32
			-- The grammar code after a form's @ ("morph:" before it allowed).
		require
			a_form: a_word.has ('@')
		do
			Result := a_word.substring (a_word.index_of ('@', 1) + 1, a_word.count)
			if Result.as_lower.starts_with ({STRING_32} "morph:") then
				Result := Result.substring (7, Result.count)
			end
		end

	lemma_language (a_text: READABLE_STRING_32): STRING_8
			-- "hbo" for Hebrew letters, "grc" for Greek, "" for plain letters (resolved by the pack).
		do
			if scripts.has_script (a_text, scripts.Script_hebrew) then
				Result := "hbo"
			elseif scripts.has_script (a_text, scripts.Script_greek) then
				Result := "grc"
			else
				Result := "any"
			end
		ensure
			not_empty: not Result.is_empty
		end

	fail (a_position: INTEGER; a_message: READABLE_STRING_GENERAL)
			-- Keep the first error.
		require
			message_not_empty: not a_message.is_empty
		do
			if error_position = 0 then
				error_position := a_position.max (1)
				error_message := a_message.to_string_32
			end
		ensure
			first_kept: error_position > 0
		end

end
