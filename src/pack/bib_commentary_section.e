note
	description: "[
		One section of a commentary on the verses it covers (Jude 5-7, or the
		whole letter for an introduction): its fields as Markdown (teaser, text,
		common reading, commentary, variants), its tagged claims, its original-
		language terms, its lists (frameworks, questions, further reading) and
		any restricted quotations, kept apart and labelled by ship class. It
		carries its pack's provenance and voice.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_COMMENTARY_SECTION

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_id, a_heading: READABLE_STRING_GENERAL; a_book, a_start_chapter, a_start_verse, a_end_chapter, a_end_verse: INTEGER;
			a_voice: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Section `a_id' over `a_book' `a_start_chapter':`a_start_verse' to `a_end_chapter':`a_end_verse'.
		require
			id_given: not a_id.is_empty
			book_positive: a_book > 0
			start_valid: a_start_chapter > 0 and a_start_verse > 0
			ordered: a_end_chapter > a_start_chapter or (a_end_chapter = a_start_chapter and a_end_verse >= a_start_verse)
			voiced: not a_voice.is_empty
		do
			section_id := a_id.to_string_32
			heading := a_heading.to_string_32
			book := a_book
			start_chapter := a_start_chapter
			start_verse := a_start_verse
			end_chapter := a_end_chapter
			end_verse := a_end_verse
			voice := a_voice.to_string_32
			provenance := a_provenance
			create fields.make (5)
			create claims.make (8)
			create terms.make (4)
			create lists.make (8)
			create restricted_quotes.make (0)
		ensure
			id_set: section_id.same_string_general (a_id)
		end

feature -- Access

	section_id, heading: STRING_32
	book, start_chapter, start_verse, end_chapter, end_verse: INTEGER
	voice: STRING_32
			-- The pack's voice for this section.
	provenance: BIB_PROVENANCE

	fields: ARRAYED_LIST [TUPLE [kind: STRING_8; markdown: STRING_32]]
			-- In BIB_COMMENTARY_SCHEMA.Field_kinds order, those the section has.
	claims: ARRAYED_LIST [BIB_COMMENTARY_CLAIM]
	terms: ARRAYED_LIST [TUPLE [script, translit, pron, english, language: STRING_32]]
	lists: ARRAYED_LIST [TUPLE [kind: STRING_8; markdown: STRING_32]]
	restricted_quotes: ARRAYED_LIST [TUPLE [source, ship_class, remark, markdown: STRING_32]]

	field (a_kind: READABLE_STRING_8): STRING_32
			-- The Markdown of field `a_kind'; empty when the section has none.
		do
			create Result.make_empty
			across fields as ic loop
				if ic.kind.same_string (a_kind) then
					Result := ic.markdown
				end
			end
		end

	claim (a_id: READABLE_STRING_GENERAL): detachable BIB_COMMENTARY_CLAIM
			-- The claim the text cites as `a_id' ("S14.1"); Void when none.
		do
			across claims as ic until Result /= Void loop
				if ic.claim_id.same_string_general (a_id) then
					Result := ic
				end
			end
		end

	covers_whole_chapter_span: BOOLEAN
			-- Does the section reach past one verse? (An introduction covers the whole letter.)
		do
			Result := end_chapter > start_chapter or end_verse > start_verse
		end

invariant
	id_given: not section_id.is_empty
	voiced: not voice.is_empty

end
