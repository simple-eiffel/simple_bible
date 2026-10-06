note
	description: "[
		The FR-053 post-check and the only creator of BIB_AI_TEXT. Wording that
		adds a digit, a reference or a Hebrew/Greek run its basis does not
		contain is withheld. The detectors arrive with the first real adapter
		(v3, RQ-11); until then they answer True, so every wording is withheld
		(fail safe), and Release 1 binds the null adapter anyway.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_AI_POST_CHECK

feature -- Factory

	checked (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT; a_model_id: READABLE_STRING_GENERAL): BIB_AI_TEXT
			-- Labeled wording about `a_basis', withheld if it adds facts.
		require
			basis_success: a_basis.is_success
			basis_cited: a_basis.citation_count > 0
			model_named: not a_model_id.is_empty
		do
			create Result.make (a_wording, a_basis, a_model_id,
				has_unsupported_digit (a_wording, a_basis) or has_unsupported_reference (a_wording, a_basis)
				or has_unsupported_script (a_wording, a_basis))
		ensure
			basis_kept: Result.basis = a_basis
			labeled: Result.is_labeled
			withheld_if_new_facts: (has_unsupported_digit (a_wording, a_basis) or has_unsupported_reference (a_wording, a_basis)
				or has_unsupported_script (a_wording, a_basis)) implies Result.is_withheld
		end

feature -- Checks

	has_unsupported_digit (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT): BOOLEAN
			-- Does `a_wording' contain a digit run the rendered basis lacks?
		do
			Result := True -- v3: digit-run comparison; fail safe until then.
		end

	has_unsupported_reference (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT): BOOLEAN
			-- Does `a_wording' name a reference (BIB_REFERENCE_DETECTOR) the basis lacks?
		do
			Result := True -- v3: reference comparison; fail safe until then.
		end

	has_unsupported_script (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT): BOOLEAN
			-- Does `a_wording' carry a Hebrew or Greek run (BIB_SCRIPT_CLASSIFIER) the basis lacks?
		do
			Result := True -- v3: script-run comparison; fail safe until then.
		end

end
