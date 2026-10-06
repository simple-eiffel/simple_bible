note
	description: "[
		Metadata of one shipped version: code, display label, edition, language,
		system, caveats, license (through its provenance), verse count and seal
		(05 addendum A-025; authoritative over 07, R-01). Never a bare "LXX"
		(FR-122, AC-1a-35); the KJV is "KJV (1769 Blayney)".
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSION_INFO

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_code: READABLE_STRING_8; a_display_label, a_edition: READABLE_STRING_GENERAL; a_language: READABLE_STRING_8;
			a_system: BIB_VERSIFICATION_SYSTEM; a_provenance: BIB_PROVENANCE; a_verse_count: INTEGER; a_seal: READABLE_STRING_8;
			a_caveat, a_quality_caveat: READABLE_STRING_GENERAL; a_septuagint, a_swete, a_morphology: BOOLEAN; a_book_ids: ITERABLE [INTEGER])
			-- Describe version `a_code' (read from core.db `version').
		require
			code_not_empty: not a_code.is_empty
			language_not_empty: not a_language.is_empty
			counted: a_verse_count > 0
			sealed: a_seal.count = 64
			never_bare_lxx: not a_display_label.same_string ({BIB_TRUST_LABELS}.Bare_lxx)
			septuagint_labeled_with_edition: a_septuagint implies (not a_edition.is_empty and a_display_label.has_substring (a_edition))
			swete_is_septuagint: a_swete implies a_septuagint
			swete_quality_caveat: a_swete implies not a_quality_caveat.is_empty
			kjv_label: a_code.same_string ("KJV") implies a_display_label.same_string ({BIB_TRUST_LABELS}.Kjv_label)
		do
			code := a_code.to_string_8
			display_label := a_display_label.to_string_32
			edition := a_edition.to_string_32
			language := a_language.to_string_8
			system := a_system
			provenance := a_provenance
			verse_count := a_verse_count
			seal := a_seal.to_string_8
			caveat := a_caveat.to_string_32
			text_quality_caveat := a_quality_caveat.to_string_32
			is_septuagint := a_septuagint
			is_swete := a_swete
			has_morphology := a_morphology
			is_right_to_left := language.same_string ("hbo") or language.same_string ("arc")
			create book_ids.make (80)
			across a_book_ids as b loop
				book_ids.extend (b)
			end
		ensure
			code_set: code.same_string (a_code)
			counted: verse_count = a_verse_count
			seal_set: seal.same_string (a_seal)
		end

feature -- Access

	code: STRING_8
			-- "BSB", "WLC", "SWETE", "WH", "KJV" ...

	display_label: STRING_32
			-- "LXX (Swete)", "KJV (1769 Blayney)".

	edition: STRING_32
	language: STRING_8
			-- "hbo", "arc", "grc", "eng", "lat".

	system: BIB_VERSIFICATION_SYSTEM

	caveat: STRING_32
			-- FR-005 version caveat.

	text_quality_caveat: STRING_32
			-- Swete: "Digital text from OCR; it may contain errors."

	license: BIB_LICENSE
			-- License of the text.
		do
			Result := provenance.license
		end

	provenance: BIB_PROVENANCE

	verse_count: INTEGER
			-- Verses in this text ("KJV 1769 . 31,102 verses . sealed").

	seal: STRING_8
			-- Per-text SHA-256 checksum from the build (BIB_TABLE_CHECKSUM).

feature -- Status

	is_septuagint: BOOLEAN
	is_swete: BOOLEAN
	is_right_to_left: BOOLEAN
	has_morphology: BOOLEAN
			-- False for Swete (no open morphology).

	has_caveat: BOOLEAN
		do
			Result := not caveat.is_empty
		end

	has_book (a_book_id: INTEGER): BOOLEAN
			-- Does this text contain book `a_book_id'?
		do
			Result := book_ids.has (a_book_id)
		ensure
			model_agrees: Result = book_ids_model [a_book_id]
		end

feature -- Model

	book_ids_model: MML_SET [INTEGER]
			-- Books this text contains (canon scope, RQ-10).
		do
			create Result
			across book_ids as b loop
				Result := Result & b
			end
		end

feature {NONE} -- Representation

	book_ids: ARRAYED_LIST [INTEGER]

invariant
	code_not_empty: not code.is_empty
	septuagint_labeled_with_edition: is_septuagint implies (not edition.is_empty and display_label.has_substring (edition))
	never_bare_lxx: not display_label.same_string_general ({BIB_TRUST_LABELS}.Bare_lxx)
	kjv_labeled: code.same_string ("KJV") implies display_label.same_string_general ({BIB_TRUST_LABELS}.Kjv_label)
	swete_is_septuagint: is_swete implies is_septuagint
	swete_quality_caveat: is_swete implies not text_quality_caveat.is_empty
	rtl_for_hebrew: language.same_string ("hbo") implies is_right_to_left
	sealed: seal.count = 64
	counted: verse_count > 0

end
