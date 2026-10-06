note
	description: "[
		The verse hub's answer: the parse outcome, the mapped reference, one
		BIB_VERSE_TEXT per requested version (text or typed omission), the words
		and the cross-references. An ambiguous reference yields no text at all
		(AC-1a-15): it is a failed answer carrying its candidates.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSE_RESULT

inherit
	BIB_ENGINE_RESULT

create
	make_found, make_unresolved

feature {NONE} -- Initialization

	make_found (a_outcome: BIB_PARSE_RESULT; a_mapped: BIB_MAPPED_REF; a_texts: ITERABLE [BIB_VERSE_TEXT]; a_words: ITERABLE [BIB_WORD];
			a_cross_references: ITERABLE [BIB_CROSS_REFERENCE]; a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
			-- The verse in every requested version.
		require
			outcome_valid: a_outcome.is_valid
			cited: across a_citations as c some True end
		do
			parse_outcome := a_outcome
			mapped := a_mapped
			create texts.make (4)
			across a_texts as t loop
				texts.extend (t)
			end
			create words.make (16)
			across a_words as w loop
				words.extend (w)
			end
			create cross_references.make (8)
			across a_cross_references as x loop
				cross_references.extend (x)
			end
			set_success (a_method, a_citations)
		ensure
			success: is_success
			mapped_set: mapped = a_mapped
		end

	make_unresolved (a_outcome: BIB_PARSE_RESULT; a_method: BIB_METHOD; a_error: BIB_ERROR)
			-- No verse: ambiguous, invalid or unmapped text.
		do
			parse_outcome := a_outcome
			create texts.make (0)
			create words.make (0)
			create cross_references.make (0)
			set_failure (a_method, a_error)
		ensure
			failed: not is_success
			no_text: version_count = 0
		end

feature -- Access

	parse_outcome: BIB_PARSE_RESULT
	mapped: detachable BIB_MAPPED_REF

	version_count: INTEGER
		do
			Result := texts.count
		end

	text_at (i: INTEGER): BIB_VERSE_TEXT
		require
			in_range: i >= 1 and i <= version_count
		do
			Result := texts [i]
		end

	word_count: INTEGER
		do
			Result := words.count
		end

	cross_reference_count: INTEGER
		do
			Result := cross_references.count
		end

feature -- Model

	texts_model: MML_SEQUENCE [BIB_VERSE_TEXT]
		do
			create Result
			across texts as t loop
				Result := Result & t
			end
		end

	words_model: MML_SEQUENCE [BIB_WORD]
		do
			create Result
			across words as w loop
				Result := Result & w
			end
		end

	cross_references_model: MML_SEQUENCE [BIB_CROSS_REFERENCE]
		do
			create Result
			across cross_references as x loop
				Result := Result & x
			end
		end

	facts_model: MML_SEQUENCE [BIB_SOURCED]
			-- Texts, words and cross-references.
		do
			create Result
			across texts as t loop
				Result := Result & t
			end
			across words as w loop
				Result := Result & w
			end
			across cross_references as x loop
				Result := Result & x
			end
		end

feature {NONE} -- Representation

	texts: ARRAYED_LIST [BIB_VERSE_TEXT]
	words: ARRAYED_LIST [BIB_WORD]
	cross_references: ARRAYED_LIST [BIB_CROSS_REFERENCE]

invariant
	found_is_mapped: is_success implies mapped /= Void
	unresolved_has_no_text: not is_success implies version_count = 0
	ambiguous_never_guessed: parse_outcome.is_ambiguous implies version_count = 0

end
