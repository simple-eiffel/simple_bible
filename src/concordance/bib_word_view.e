note
	description: "[
		The word view (research/14 section 3): the heading, the total of places,
		the FIRST page of the every-place list, and the ten sections in the
		approved order. Later pages come from the place-page query; the view
		never holds a whole list. Sections absent from the pack (for example the
		Greek Old Testament in conc_dist.db) are reported by `is_present', not
		faked.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WORD_VIEW

inherit
	BIB_ENGINE_RESULT

create
	make_success, make_failure

feature {NONE} -- Initialization

	make_success (a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE]; a_entry: BIB_WORD_ENTRY; a_place_total: BIB_FACT [INTEGER_64]; a_first_places: BIB_LIST_RESULT [BIB_PLACE_ROW])
			-- A word view of `a_entry'.
		require
			cited: across a_citations as c some True end
			first_page_succeeded: a_first_places.is_success
			total_covers_page: a_first_places.count <= a_place_total.value
		do
			check implemented_in_phase_4: False then end
		ensure
			success: is_success
			entry_set: entry = a_entry
			total_set: place_total = a_place_total
		end

	make_failure (a_method: BIB_METHOD; a_error: BIB_ERROR)
		do
			check implemented_in_phase_4: False then end
		ensure
			failed: not is_success
		end

feature -- Access

	entry: detachable BIB_WORD_ENTRY
	place_total: detachable BIB_FACT [INTEGER_64]
	first_places: detachable BIB_LIST_RESULT [BIB_PLACE_ROW]

	section_count: INTEGER
			-- Number of sections the pack can answer for this word.
		do
			Result := present_names.count
		end

	section_name (i: INTEGER): STRING_8
			-- The `i'-th present section, in the approved order.
		require
			in_range: i >= 1 and i <= section_count
		do
			check implemented_in_phase_4: False then end
		ensure
			known: is_known_section (Result)
		end

feature -- Status

	is_known_section (a_name: READABLE_STRING_8): BOOLEAN
			-- One of: heading, how_often, english, dictionaries, centuries, callout, every_place, greek_ot, going_further, notes.
		do
			check implemented_in_phase_4: False then end
		end

	is_present (a_name: READABLE_STRING_8): BOOLEAN
			-- Does this view carry section `a_name'?
		require
			known: is_known_section (a_name)
		do
			check implemented_in_phase_4: False then end
		ensure
			heading_when_success: (is_success and a_name.same_string ("heading")) implies Result
			every_place_when_success: (is_success and a_name.same_string ("every_place")) implies Result
		end

	is_in_approved_order: BOOLEAN
			-- Are the present sections in research/14 section 3 order?
		do
			check implemented_in_phase_4: False then end
		end

feature -- Model

	facts_model: MML_SEQUENCE [BIB_SOURCED]
			-- The entry, the place total and the first page's rows: every fact the
			-- view carries (scan 23: it was always empty, so `fact_closure' could
			-- not fail).
		do
			create Result
			if attached entry as al_entry then
				Result := Result & al_entry
			end
			if attached place_total as al_total then
				Result := Result & al_total
			end
			if attached first_places as al_places then
				Result := Result + al_places.facts_model
			end
		end

feature {NONE} -- Representation

	present_names: ARRAYED_LIST [STRING_8]

invariant
	success_has_entry: is_success = (entry /= Void)
	success_has_total: is_success = (place_total /= Void)
	order_kept: is_success implies is_in_approved_order

end
