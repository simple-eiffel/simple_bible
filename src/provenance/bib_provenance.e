note
	description: "[
		Where a fact came from: the `source_provenance' row (key), source,
		edition, license, caveat and grade. AI-made build-time data is flagged
		with its method and model id (D-016, AC-1a-33). Every shipped table
		carries `provenance_key INTEGER NOT NULL REFERENCES source_provenance'
		(RQ-02); `key' is that value, so two provenances are equal when their
		keys are.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PROVENANCE

inherit
	ANY
		redefine
			is_equal
		end

create
	make, make_ai_made, make_graded

feature {NONE} -- Initialization

	make (a_key: INTEGER_64; a_source_key, a_edition: READABLE_STRING_GENERAL; a_license: BIB_LICENSE; a_caveat: READABLE_STRING_GENERAL)
			-- Create the provenance of row `a_key' in `source_provenance'.
		require
			key_positive: a_key > 0
			source_named: not a_source_key.is_empty
		do
			key := a_key
			source_key := a_source_key.to_string_32
			edition := a_edition.to_string_32
			license := a_license
			caveat := a_caveat.to_string_32
			create method_label.make_empty
			create model_id.make_empty
		ensure
			key_set: key = a_key
			source_set: source_key.same_string_general (a_source_key)
			edition_set: edition.same_string_general (a_edition)
			license_set: license = a_license
			caveat_set: caveat.same_string_general (a_caveat)
			not_ai: not is_ai_made
			ungraded: grade = Void and not requires_grade
		end

	make_ai_made (a_key: INTEGER_64; a_source_key, a_edition: READABLE_STRING_GENERAL; a_license: BIB_LICENSE; a_method, a_model: READABLE_STRING_GENERAL)
			-- Create the provenance of AI-made build-time data (labeled, with method and model id).
		require
			key_positive: a_key > 0
			source_named: not a_source_key.is_empty
			method_named: not a_method.is_empty
			model_named: not a_model.is_empty
		do
			make (a_key, a_source_key, a_edition, a_license, {STRING_32} "")
			is_ai_made := True
			method_label := a_method.to_string_32
			model_id := a_model.to_string_32
		ensure
			key_set: key = a_key
			ai: is_ai_made
			method_set: method_label.same_string_general (a_method)
			model_set: model_id.same_string_general (a_model)
		end

	make_graded (a_key: INTEGER_64; a_source_key, a_edition: READABLE_STRING_GENERAL; a_license: BIB_LICENSE; a_grade: BIB_GRADE)
			-- Create the provenance of a source class that must be graded (timeline, private).
		require
			key_positive: a_key > 0
			source_named: not a_source_key.is_empty
		do
			make (a_key, a_source_key, a_edition, a_license, {STRING_32} "")
			grade := a_grade
			requires_grade := True
		ensure
			key_set: key = a_key
			graded: grade = a_grade and requires_grade
		end

feature -- Access

	key: INTEGER_64
			-- Row id in `source_provenance' (the NOT NULL foreign key every shipped row carries).

	source_key: STRING_32
			-- Source, e.g. "WLC", "SBLGNT", "SWETE", "OB-XREF".

	edition: STRING_32
			-- Edition label, e.g. "Swete 1909-1930 (First1KGreek)".

	license: BIB_LICENSE
			-- License of the source.

	caveat: STRING_32
			-- Version caveat (FR-005); may be empty.

	grade: detachable BIB_GRADE
			-- P1-P4 where the source class requires it.

	method_label: STRING_32
			-- For AI-made data: how it was made, e.g. "meaning neighbor, bge-m3, computed at build time".

	model_id: STRING_32
			-- For AI-made data: the model id.

feature -- Status

	is_ai_made: BOOLEAN
			-- Was this data made by an AI model at build time?

	requires_grade: BOOLEAN
			-- Must this source be graded (timeline and private sources)?

	has_caveat: BOOLEAN
			-- Is there a caveat to show?
		do
			Result := not caveat.is_empty
		end

	is_share_alike: BOOLEAN
			-- Does the source's license require share-alike?
		do
			Result := license.is_share_alike
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Same `source_provenance' row?
		do
			Result := key = other.key and source_key.same_string (other.source_key)
		end

invariant
	key_positive: key > 0
	source_named: not source_key.is_empty
	ai_made_has_method: is_ai_made implies (not method_label.is_empty and not model_id.is_empty)
	graded_when_required: requires_grade implies grade /= Void

end
