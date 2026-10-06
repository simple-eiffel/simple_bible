note
	description: "[
		A named structural pattern (shape.db). Its definition is written before
		any run; T3 shapes may frame a question, never score one (ROE Rule 21 S3).
		An absent tag gives NO_DATA, never FAILS (DR-005).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_SHAPE

feature -- Definition (fixed before any run)

	slug: STRING_32
		deferred
		end

	name: STRING_32
		deferred
		end

	tier: BIB_SHAPE_TIER
		deferred
		end

	definition_formal: STRING_32
		deferred
		end

	definition_prose: STRING_32
		deferred
		end

	could_fail_if: STRING_32
		deferred
		end

	seeded_by: STRING_32
			-- self / larry / vault:<file> / scholar:<name> / foil:<position>
		deferred
		end

	required_columns: ARRAY [STRING_8]
			-- core.db columns the shape reads (AC-1a-26).
		deferred
		end

	corpus: BIB_SEARCH_SCOPE
		deferred
		end

feature -- Classification

	classify (a_candidate: BIB_SHAPE_CANDIDATE): BIB_SHAPE_FINDING
		require
			candidate_in_corpus: corpus.contains (a_candidate.ref)
		deferred
		ensure
			absent_tag_is_no_data: not a_candidate.has_required_tags (required_columns) implies Result.verdict.is_no_data
			tier_carried: Result.tier ~ tier
			grounds_given: not Result.grounds.is_empty
			same_verse: Result.hub_id = a_candidate.hub_id
		end

invariant
	defined_before_run: not definition_formal.is_empty and not definition_prose.is_empty and not could_fail_if.is_empty
	seeded: not seeded_by.is_empty
	slug_valid: not slug.is_empty
	declares_columns: not required_columns.is_empty

end
