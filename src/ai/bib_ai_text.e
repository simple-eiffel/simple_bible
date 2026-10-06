note
	description: "[
		Model wording about one engine answer: labeled, post-checked, never a
		fact source (I-001, DR-012). ONLY BIB_AI_POST_CHECK can create one, and
		only from a successful, cited engine result, so AI text without an
		engine answer cannot exist. Withheld wording shows nothing.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_AI_TEXT

create {BIB_AI_POST_CHECK}
	make

feature {NONE} -- Initialization

	make (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT; a_model_id: READABLE_STRING_GENERAL; a_withheld: BOOLEAN)
		require
			basis_success: a_basis.is_success
			basis_cited: a_basis.citation_count > 0
			model_named: not a_model_id.is_empty
		do
			basis := a_basis
			model_id := a_model_id.to_string_32
			is_withheld := a_withheld
			if a_withheld then
				create displayable_text.make_empty
			else
				displayable_text := a_wording.to_string_32
			end
			label := {BIB_TRUST_LABELS}.Ai_wording_label
		ensure
			basis_set: basis = a_basis
			withheld_set: is_withheld = a_withheld
		end

feature -- Access

	basis: BIB_ENGINE_RESULT
	displayable_text: STRING_32
	model_id: STRING_32
	label: STRING_32

feature -- Status

	is_withheld: BOOLEAN

	is_labeled: BOOLEAN
		do
			Result := label.same_string ({BIB_TRUST_LABELS}.Ai_wording_label)
		end

invariant
	label_present: is_labeled
	cites_engine: basis.is_success and basis.citation_count > 0
	model_named: not model_id.is_empty
	withheld_text_hidden: is_withheld implies displayable_text.is_empty

end
