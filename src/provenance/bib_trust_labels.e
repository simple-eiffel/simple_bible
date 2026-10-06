note
	description: "[
		The fixed wording of the trust rules (Q-14, A-029): labels that must
		appear verbatim wherever their condition holds. One place, so a test can
		grep for them and no face can paraphrase them.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TRUST_LABELS

feature -- Labels

	Ai_made_label: STRING_32 = "AI-made"
			-- Shown on every AI-made item and kept in every export (D-016, AC-1a-33, AC-1a-54).

	Ai_wording_label: STRING_32 = "AI wording; the facts above are from the engine"
			-- Shown on every BIB_AI_TEXT (I-001).

	Surface_form_label: STRING_32 = "surface-form match"
			-- Divine-name marks found by surface form (Swete has no open morphology, AC-1a-29).

	Kjv_label: STRING_32 = "KJV (1769 Blayney)"
			-- The only display label of the KJV (RQ-10, AC-1a-35).

	Bare_lxx: STRING_32 = "LXX"
			-- A label no version may carry alone (FR-122).

	Omitted_in_edition: STRING_32 = "omitted in this edition"
			-- WH omission text (AC-1a-19).

	Not_in_canon: STRING_32 = "not in this canon"
			-- Text without the book (AC-1a-19, RQ-10).

	Ocr_note: STRING_32 = "OCR"
			-- Substring every uncollated-OCR edition note carries (AC-1a-27).

end
