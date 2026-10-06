note
	description: "One section of a guide: id, kind, title and the engine result it shows. A section always holds data."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_GUIDE_SECTION

create
	make

feature {NONE} -- Initialization

	make (a_id, a_kind: INTEGER; a_title: READABLE_STRING_GENERAL; a_result: BIB_ENGINE_RESULT)
		require
			id_positive: a_id > 0
			kind_valid: is_valid_kind (a_kind)
			title_not_empty: not a_title.is_empty
			has_data: a_result.is_success and a_result.citation_count > 0
		do
			id := a_id
			kind := a_kind
			title := a_title.to_string_32
			result_value := a_result
		end

feature -- Access

	id: INTEGER
	kind: INTEGER
	title: STRING_32
	result_value: BIB_ENGINE_RESULT

feature -- Status

	is_valid_kind (a_kind: INTEGER): BOOLEAN
		do
			Result := a_kind >= Section_text and a_kind <= Section_lens
		end

	is_commentary_kind: BOOLEAN
			-- Library, author or lens section (excluded in text-first mode, S9)?
		do
			Result := kind = Section_library or kind = Section_author or kind = Section_lens
		end

feature -- Constants

	Section_text: INTEGER = 1
	Section_words: INTEGER = 2
	Section_cross_references: INTEGER = 3
	Section_related: INTEGER = 4
	Section_quotation: INTEGER = 5
	Section_renderings: INTEGER = 6
	Section_journey: INTEGER = 7
	Section_library: INTEGER = 8
	Section_author: INTEGER = 9
	Section_lens: INTEGER = 10

invariant
	has_data: result_value.is_success and result_value.citation_count > 0
	kind_valid: is_valid_kind (kind)

end
