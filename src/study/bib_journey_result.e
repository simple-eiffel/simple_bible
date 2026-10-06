note
	description: "A word's journey: witnesses in time order, each with counts and a method (FR-108)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_JOURNEY_RESULT

inherit
	BIB_ENGINE_RESULT

create
	make_success, make_failure

feature {NONE} -- Initialization

	make_success (a_key: BIB_KEY; a_rows: ITERABLE [BIB_JOURNEY_ROW]; a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
		require
			cited: across a_citations as c some True end
		do
			key := a_key
			create rows.make (8)
			across a_rows as r loop
				rows.extend (r)
			end
			set_success (a_method, a_citations)
		end

	make_failure (a_key: BIB_KEY; a_method: BIB_METHOD; a_error: BIB_ERROR)
		do
			key := a_key
			create rows.make (0)
			set_failure (a_method, a_error)
		end

feature -- Access

	key: BIB_KEY

	count: INTEGER
		do
			Result := rows.count
		end

	row (i: INTEGER): BIB_JOURNEY_ROW
		require
			in_range: i >= 1 and i <= count
		do
			Result := rows [i]
		end

	is_time_ordered: BOOLEAN
			-- Are the rows in non-decreasing year order?
		do
			Result := across 2 |..| rows.count as i all rows [i - 1].year <= rows [i].year end
		end

feature -- Model

	rows_model: MML_SEQUENCE [BIB_JOURNEY_ROW]
		do
			create Result
			across rows as r loop
				Result := Result & r
			end
		end

	facts_model: MML_SEQUENCE [BIB_SOURCED]
		do
			create Result
			across rows as r loop
				Result := Result & r
			end
		end

feature {NONE} -- Representation

	rows: ARRAYED_LIST [BIB_JOURNEY_ROW]

end
