note
	description: "One node of a query clause tree: word, phrase, and/or/not, regex, lemma, Strong's, morphology."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUERY_CLAUSE

create
	make_text, make_key, make_operator

feature {NONE} -- Initialization

	make_text (a_kind: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- Word, phrase or regex clause.
		require
			text_kind: a_kind = Word or a_kind = Phrase or a_kind = Regex
			text_not_empty: not a_text.is_empty
		do
			kind := a_kind
			text := a_text.to_string_32
		ensure
			kind_set: kind = a_kind
		end

	make_key (a_kind: INTEGER; a_key: BIB_KEY)
			-- Lemma, Strong's or morphology clause.
		require
			key_kind: a_kind = Lemma or a_kind = Strongs or a_kind = Morph
		do
			kind := a_kind
			key := a_key
			text := a_key.text
		ensure
			kind_set: kind = a_kind
			key_set: key = a_key
		end

	make_operator (a_kind: INTEGER; a_child_count: INTEGER)
			-- And, or or not node over the next `a_child_count' subtrees (pre-order).
		require
			operator_kind: a_kind = And_clause or a_kind = Or_clause or a_kind = Not_clause
			arity: (a_kind = Not_clause implies a_child_count = 1) and (a_kind /= Not_clause implies a_child_count >= 2)
		do
			kind := a_kind
			child_count := a_child_count
			create text.make_empty
		ensure
			kind_set: kind = a_kind
			children_set: child_count = a_child_count
		end

feature -- Access

	kind: INTEGER
	text: STRING_32
	key: detachable BIB_KEY
	child_count: INTEGER

feature -- Status

	is_key_clause: BOOLEAN
		do
			Result := kind = Lemma or kind = Strongs or kind = Morph
		end

	is_operator: BOOLEAN
		do
			Result := kind = And_clause or kind = Or_clause or kind = Not_clause
		end

feature -- Constants

	Word: INTEGER = 1
	Phrase: INTEGER = 2
	And_clause: INTEGER = 3
	Or_clause: INTEGER = 4
	Not_clause: INTEGER = 5
	Regex: INTEGER = 6
	Lemma: INTEGER = 7
	Strongs: INTEGER = 8
	Morph: INTEGER = 9

invariant
	kind_valid: kind >= Word and kind <= Morph
	key_clause_has_key: is_key_clause implies key /= Void
	operator_has_children: is_operator implies child_count >= 1
	leaf_has_no_children: not is_operator implies child_count = 0

end
