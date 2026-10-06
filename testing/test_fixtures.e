note
	description: "[
		Small in-memory fixtures for the Phase 1 tests: licenses, provenances,
		methods, references and version infos. No database and no private data;
		the core.db fixture and golden outputs arrive with Phase 5 under
		testing/fixtures/.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_FIXTURES

feature -- Licenses

	public_domain: BIB_LICENSE
		do
			create Result.make ("PD", False, False, False, "")
		end

	cc_by_sa: BIB_LICENSE
		do
			create Result.make ("CC-BY-SA-4.0", False, True, False, "First1KGreek / OGL, CC BY-SA 4.0")
		end

	cc_by_nc: BIB_LICENSE
		do
			create Result.make ("CC-BY-NC-4.0", True, False, False, "CC BY-NC 4.0")
		end

	unknown_license: BIB_LICENSE
		do
			create Result.make ({BIB_LICENSE}.Unknown_identifier, False, False, False, "")
		end

	ccat_restricted: BIB_LICENSE
		do
			create Result.make ("CCAT-USER-DECLARATION", True, True, True, "CATSS (permission required)")
		end

feature -- Provenance

	provenance (a_key: INTEGER_64; a_source: STRING_8): BIB_PROVENANCE
		require
			key_positive: a_key > 0
		do
			create Result.make (a_key, a_source, a_source + " edition", public_domain, "")
		end

	swete_provenance: BIB_PROVENANCE
		do
			create Result.make (3, "SWETE", "Swete 1909-1930 (First1KGreek)", cc_by_sa, "Digital text from OCR; it may contain errors.")
		end

	ai_provenance: BIB_PROVENANCE
		do
			create Result.make_ai_made (9, "AI-NEIGHBORS", "build 2026-10-06", public_domain, "meaning neighbor, bge-m3, computed at build time", "BAAI/bge-m3")
		end

feature -- Methods

	method (a_feature: STRING_8): BIB_METHOD
		do
			create Result.make (a_feature, "q", "NT", "NT, SBLGNT, word tokens", <<"SBLGNT">>, {ARRAY [STRING_8]} <<>>,
				{ARRAY [INTEGER_64]} <<1>>, "0.1.0", "2026-10-06", "3.31.1")
		end

feature -- References

	kjv: BIB_VERSIFICATION_SYSTEM
		do
			create Result.make_kjv
		end

	ref (a_book, a_chapter, a_verse: INTEGER): BIB_REF
		do
			create Result.make (a_book, a_chapter, a_verse, kjv)
		end

feature -- Versions

	seal: STRING_8
			-- A well-formed 64-character seal.
		do
			create Result.make_filled ('a', 64)
		end

	version_info (a_code: STRING_8; a_label, a_edition: STRING_32; a_language: STRING_8; a_septuagint, a_swete: BOOLEAN): BIB_VERSION_INFO
		do
			create Result.make (a_code, a_label, a_edition, a_language, kjv, provenance (1, a_code), 31102, seal, "",
				(if a_swete then {STRING_32} "Digital text from OCR; it may contain errors." else {STRING_32} "" end),
				a_septuagint, a_swete, not a_swete, {ARRAY [INTEGER]} <<1, 2, 3>>)
		end

end
