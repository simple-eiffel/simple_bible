note
	description: "[
		Counts and hits by key (FR-023): lemma, Strong's, morphology. "H1",
		"H0001" and "H00001" are one key; split senses (6743/6743a) are counted
		separately; for unsplit lemmas the Strong's count equals the lemma count
		(AC-1a-22). Every count states its scope.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CONCORDANCE

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
		end

feature -- Counting

	count (a_key: BIB_KEY; a_scope: BIB_SEARCH_SCOPE): BIB_COUNT_RESULT
			-- Occurrences of `a_key' in `a_scope', per book.
		do
			check implemented_in_phase_4: False then end
		ensure
			same_key: Result.key ~ a_key
			scope_stated: Result.method.scope_label.same_string (a_scope.label)
			method_recorded: Result.method.engine_feature.same_string_general ("concordance")
			unsplit_strongs_equals_lemma: (Result.is_success and then attached {BIB_STRONGS_KEY} a_key as s and then s.sense_suffix.is_empty and then not is_split (s))
				implies (attached Result.total as t and then t.value = lemma_total_for (s, a_scope))
			fact_closure: Result.is_fact_closed
		end

	hits (a_key: BIB_KEY; a_scope: BIB_SEARCH_SCOPE): BIB_SEARCH_JOB
			-- Paged hits of `a_key' (a job; one chunk per book).
		do
			check implemented_in_phase_4: False then end
		ensure
			not_started: not Result.is_started
			chunked_by_book: Result.chunk_total = a_scope.book_count
		end

feature -- Status

	is_split (a_key: BIB_STRONGS_KEY): BOOLEAN
			-- Does `a_key' have lettered senses (6743/6743a)?
		do
			-- Phase 4
		end

	lemma_total_for (a_key: BIB_STRONGS_KEY; a_scope: BIB_SEARCH_SCOPE): INTEGER_64
			-- Count of the lemma that `a_key' denotes, in `a_scope'.
		do
			-- Phase 4
		ensure
			non_negative: Result >= 0
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
