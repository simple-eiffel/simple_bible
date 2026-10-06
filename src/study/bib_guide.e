note
	description: "[
		An engine-assembled guide (FR-110): Passage Guide, Word Study, They Chose,
		Word's Journey. Ordered sections, none empty; in text-first mode no
		library, author or lens section (S9, AC-1a-38). Per C-019 the "no empty
		section" rule lives on the only ways in (creation and `add_section').
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_GUIDE

inherit
	BIB_ENGINE_RESULT

create
	make

feature {NONE} -- Initialization

	make (a_kind: INTEGER; a_text_first: BOOLEAN; a_first: BIB_GUIDE_SECTION; a_method: BIB_METHOD)
		require
			kind_valid: a_kind >= Passage_guide and a_kind <= Word_journey
			allowed: a_text_first implies not a_first.is_commentary_kind
		local
			l_citations: ARRAYED_LIST [BIB_PROVENANCE]
			i: INTEGER
		do
			kind := a_kind
			is_text_first := a_text_first
			create sections.make (8)
			sections.extend (a_first)
			create l_citations.make (a_first.result_value.citation_count)
			from
				i := 1
			until
				i > a_first.result_value.citation_count
			loop
				l_citations.extend (a_first.result_value.citation (i))
				i := i + 1
			end
			set_success (a_method, l_citations)
		ensure
			one_section: section_count = 1
		end

feature -- Access

	kind: INTEGER
	is_text_first: BOOLEAN

	section_count: INTEGER
		do
			Result := sections.count
		end

	section (i: INTEGER): BIB_GUIDE_SECTION
		require
			in_range: i >= 1 and i <= section_count
		do
			Result := sections [i]
		end

feature -- Status

	has_section (a_id: INTEGER): BOOLEAN
		do
			Result := across sections as s some s.id = a_id end
		end

	has_section_kind (a_kind: INTEGER): BOOLEAN
		do
			Result := across sections as s some s.kind = a_kind end
		end

feature {BIB_GUIDE_JOB} -- Assembly

	add_section (a_section: BIB_GUIDE_SECTION)
		require
			has_data: a_section.result_value.is_success and a_section.result_value.citation_count > 0
			unique_id: not has_section (a_section.id)
			text_first_respected: is_text_first implies not a_section.is_commentary_kind
		do
			-- Phase 4: append; extend citations with the section's citations.
		ensure
			appended: sections_model |=| (old sections_model & a_section)
			citations_grown: citation_count >= old citation_count
		end

feature -- Model

	sections_model: MML_SEQUENCE [BIB_GUIDE_SECTION]
		do
			create Result
			across sections as s loop
				Result := Result & s
			end
		end

	facts_model: MML_SEQUENCE [BIB_SOURCED]
			-- The facts of every section.
		do
			create Result
			across sections as s loop
				Result := Result + s.result_value.facts_model
			end
		end

feature {NONE} -- Representation

	sections: ARRAYED_LIST [BIB_GUIDE_SECTION]

feature -- Constants

	Passage_guide: INTEGER = 1
	Word_study: INTEGER = 2
	They_chose: INTEGER = 3
	Word_journey: INTEGER = 4

invariant
	never_empty: section_count >= 1
	kind_valid: kind >= Passage_guide and kind <= Word_journey

end
