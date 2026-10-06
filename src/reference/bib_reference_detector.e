note
	description: "[
		Explicit references in free text: a function-for-function port of
		build_rix_db.py R12 (alias table, colon and period forms, de-duplication)
		plus scripture_detect.py's explicit detector (D-020; accepted by a
		differential test in bible_build). Also finds verse links in Markdown
		notes as plain references (RQ-06), so no proprietary link syntax exists.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_REFERENCE_DETECTOR

create
	make

feature {NONE} -- Initialization

	make (a_books: BIB_BOOK_CATALOG)
			-- Create a detector over `a_books'.
		do
			books := a_books
		ensure
			books_set: books = a_books
		end

feature -- Access

	books: BIB_BOOK_CATALOG

feature -- Detection

	detected (a_text: READABLE_STRING_32): ARRAYED_LIST [BIB_REF_MATCH]
			-- Every explicit reference in `a_text', in text order.
		do
			check implemented_in_phase_4: False then end
		ensure
			within_text: across Result as m all m.finish <= a_text.count end
			known_books: across Result as m all books.has_book (m.ref.book_id) end
			in_text_order: across 2 |..| Result.count as i all Result [i - 1].start <= Result [i].start end
			period_form_checked: across Result as m all m.is_period_form implies
				(m.ref.chapter >= 1 and m.ref.chapter <= books.chapter_count (m.ref.book_id, m.ref.system) and m.ref.verse >= 1) end
		end

	distinct_references (a_text: READABLE_STRING_32): ARRAYED_LIST [BIB_REF]
			-- R12: each referenced verse once, first verse only for ranges.
		do
			check implemented_in_phase_4: False then end
		ensure
			deduplicated: Result.count = distinct_count (Result)
			from_detection: Result.count <= detected (a_text).count
		end

feature -- Measurement

	distinct_count (a_refs: ARRAYED_LIST [BIB_REF]): INTEGER
			-- Number of distinct references in `a_refs'.
		local
			l_set: MML_SET [BIB_REF]
		do
			create l_set
			across a_refs as r loop
				l_set := l_set & r
			end
			Result := l_set.count
		end

end
