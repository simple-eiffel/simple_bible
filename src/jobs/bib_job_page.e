note
	description: "[
		One page of copied rows: hub ids and display lines, plain values only.
		`make_from_separate' imports a page built on a job's processor into the
		mailbox's processor, so no face ever holds a reference into a worker.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_JOB_PAGE

create
	make, make_from_separate

feature {NONE} -- Initialization

	make (a_number: INTEGER)
			-- Empty page `a_number'.
		require
			number_positive: a_number >= 1
		do
			number := a_number
			create ids.make (32)
			create rows.make (32)
		ensure
			number_set: number = a_number
			empty: row_count = 0
		end

	make_from_separate (other: separate BIB_JOB_PAGE)
			-- Copy of `other' on the current processor.
		local
			i: INTEGER
		do
			number := other.number
			create ids.make (other.row_count)
			create rows.make (other.row_count)
			from
				i := 1
			until
				i > other.row_count
			loop
				ids.extend (other.row_id (i))
				rows.extend (create {STRING_32}.make_from_separate (other.row_text (i)))
				i := i + 1
			end
		ensure
			same_number: number = other.number
			same_size: row_count = other.row_count
		end

feature -- Access

	number: INTEGER

	row_count: INTEGER
		do
			Result := rows.count
		end

	row_id (i: INTEGER): INTEGER_64
		require
			in_range: i >= 1 and i <= row_count
		do
			Result := ids [i]
		end

	row_text (i: INTEGER): STRING_32
		require
			in_range: i >= 1 and i <= row_count
		do
			Result := rows [i]
		end

feature -- Element change

	add_row (a_id: INTEGER_64; a_text: READABLE_STRING_GENERAL)
		do
			ids.extend (a_id)
			rows.extend (a_text.to_string_32)
		ensure
			ids_appended: ids_model |=| (old ids_model & a_id)
			grown: row_count = old row_count + 1
		end

feature -- Model

	ids_model: MML_SEQUENCE [INTEGER_64]
		do
			create Result
			across ids as i loop
				Result := Result & i
			end
		end

	rows_model: MML_SEQUENCE [STRING_32]
		do
			create Result
			across rows as r loop
				Result := Result & r
			end
		end

feature {NONE} -- Representation

	ids: ARRAYED_LIST [INTEGER_64]
	rows: ARRAYED_LIST [STRING_32]

invariant
	number_positive: number >= 1
	aligned: ids.count = rows.count

end
