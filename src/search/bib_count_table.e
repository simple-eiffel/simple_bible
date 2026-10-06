note
	description: "[
		Per-book counts and corpus sizes (FR-115): frequency per 1,000 words is
		always computed against the stated corpus size, never a bare count.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_COUNT_TABLE

create
	make

feature {NONE} -- Initialization

	make
		do
			create counts.make (66)
			create sizes.make (66)
		ensure
			empty: total = 0
		end

feature -- Access

	count (a_book_id: INTEGER): INTEGER_64
		require
			has_book: has_book (a_book_id)
		do
			Result := counts.item (a_book_id)
		end

	corpus_size (a_book_id: INTEGER): INTEGER_64
		require
			has_book: has_book (a_book_id)
		do
			Result := sizes.item (a_book_id)
		end

	total: INTEGER_64
			-- Sum of all book counts.
		do
			across counts as c loop
				Result := Result + c
			end
		end

	frequency_per_thousand (a_book_id: INTEGER): REAL_64
			-- Count per 1,000 units of `a_book_id'.
		require
			has_book: has_book (a_book_id)
			sized: corpus_size (a_book_id) > 0
		do
			Result := count (a_book_id) * 1000.0 / corpus_size (a_book_id)
		ensure
			non_negative: Result >= 0.0
		end

feature -- Status

	has_book (a_book_id: INTEGER): BOOLEAN
		do
			Result := counts.has (a_book_id)
		ensure
			model_agrees: Result = counts_model.domain [a_book_id]
		end

feature {BIB_CONCORDANCE, BIB_SEARCH_JOB} -- Filling

	put_book (a_book_id: INTEGER; a_count, a_size: INTEGER_64)
			-- Record `a_count' hits in `a_size' units for `a_book_id'.
		require
			new_book: not has_book (a_book_id)
			counts_sane: a_count >= 0 and a_size >= a_count
		do
			counts.put (a_count, a_book_id)
			sizes.put (a_size, a_book_id)
		ensure
			counted: counts_model |=| old counts_model.updated (a_book_id, a_count)
			sized: sizes_model |=| old sizes_model.updated (a_book_id, a_size)
		end

feature -- Model

	counts_model: MML_MAP [INTEGER, INTEGER_64]
		do
			create Result
			across counts as c loop
				Result := Result.updated (@c.key, c)
			end
		end

	sizes_model: MML_MAP [INTEGER, INTEGER_64]
		do
			create Result
			across sizes as s loop
				Result := Result.updated (@s.key, s)
			end
		end

feature {NONE} -- Representation

	counts: HASH_TABLE [INTEGER_64, INTEGER]
	sizes: HASH_TABLE [INTEGER_64, INTEGER]

invariant
	same_books: counts.count = sizes.count

end
