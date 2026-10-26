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
			entry := a_entry
			place_total := a_place_total
			first_places := a_first_places
				-- The sections this view has facts for; the others (english, dictionaries,
				-- centuries, callout, greek_ot, going_further, notes) join as their data does.
			create present_names.make_from_array (<<"heading", "how_often", "every_place">>)
			set_success (a_method, a_citations)
		ensure
			success: is_success
			method_set: method = a_method
			entry_set: entry = a_entry
			total_set: place_total = a_place_total
			places_set: first_places = a_first_places
			order_kept: is_in_approved_order
		end

	make_failure (a_method: BIB_METHOD; a_error: BIB_ERROR)
		do
			create present_names.make (0)
			set_failure (a_method, a_error)
		ensure
			failed: not is_success
			method_set: method = a_method
			error_set: error = a_error
			empty_model: facts_model.is_empty
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
			Result := present_names.i_th (i)
		ensure
			known: is_known_section (Result)
		end

feature -- Status

	is_known_section (a_name: READABLE_STRING_8): BOOLEAN
			-- One of: heading, how_often, english, dictionaries, centuries, callout, every_place, greek_ot, going_further, notes.
			-- Compared by content, never with `has' (object identity on strings, oracle gotcha).
		do
			Result := across approved_order as n some n.same_string (a_name) end
		ensure
			definition: Result = across approved_order as n some n.same_string (a_name) end
		end

	approved_position (a_name: READABLE_STRING_8): INTEGER
			-- Place of `a_name' in `approved_order' (1-based); 0 when `a_name' is not a known section.
		local
			l_i: INTEGER
		do
			from
				l_i := 1
			until
				l_i > approved_order.count or Result > 0
			loop
				if approved_order [l_i].same_string (a_name) then
					Result := l_i
				end
				l_i := l_i + 1
			end
		ensure
			zero_when_unknown: (Result = 0) = not is_known_section (a_name)
			named: Result > 0 implies approved_order [Result].same_string (a_name)
		end

	is_present (a_name: READABLE_STRING_8): BOOLEAN
			-- Does this view carry section `a_name'?
		require
			known: is_known_section (a_name)
		do
			Result := across present_names as n some n.same_string (a_name) end
		ensure
			heading_when_success: (is_success and a_name.same_string ("heading")) implies Result
			every_place_when_success: (is_success and a_name.same_string ("every_place")) implies Result
		end

	is_in_approved_order: BOOLEAN
			-- Are the present sections in research/14 section 3 order?
		local
			i: INTEGER
		do
			Result := across present_names as n all is_known_section (n) end
			from
				i := 1
			until
				not Result or i >= present_names.count
			loop
				Result := approved_position (present_names.i_th (i)) < approved_position (present_names.i_th (i + 1))
				i := i + 1
			end
		ensure
			subsequence: Result implies (across present_names as n all is_known_section (n) end and across 1 |..| (present_names.count - 1) as l_i all approved_position (present_names.i_th (l_i)) < approved_position (present_names.i_th (l_i + 1)) end)
		end

feature -- Constants

	approved_order: ARRAY [STRING_8]
			-- The ten sections in research/14 section 3 order (ruling 1.6; the contract's own names).
		once
			Result := <<"heading", "how_often", "english", "dictionaries", "centuries", "callout", "every_place", "greek_ot", "going_further", "notes">>
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
	success_has_places: is_success = (first_places /= Void)

end
