note
	description: "[
		One line of the navigator's books tree (T1, P11): a testament, a book
		or a chapter. Testaments and books open lazily; a chapter opens in the
		Bible text.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NAV_NODE

create
	make_testament,
	make_book,
	make_chapter

feature {NONE} -- Initialization

	make_testament (a_label: READABLE_STRING_GENERAL; a_first, a_last: INTEGER)
			-- A testament holding books `a_first' to `a_last'.
		require
			label_not_empty: not a_label.is_empty
			range: 1 <= a_first and a_first <= a_last
		do
			label := a_label.to_string_32
			first_book := a_first
			last_book := a_last
		ensure
			a_testament: is_testament
		end

	make_book (a_label: READABLE_STRING_GENERAL; a_book: INTEGER)
			-- Book `a_book', called `a_label'.
		require
			label_not_empty: not a_label.is_empty
			book_positive: a_book > 0
		do
			label := a_label.to_string_32
			book_id := a_book
		ensure
			a_book_node: is_book
		end

	make_chapter (a_book, a_chapter: INTEGER)
			-- Chapter `a_chapter' of book `a_book'.
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
		do
			label := {STRING_32} "Chapter " + a_chapter.out
			book_id := a_book
			chapter := a_chapter
		ensure
			a_chapter_node: is_chapter
		end

feature -- Access

	label: STRING_32
	first_book, last_book: INTEGER
			-- A testament's books.
	book_id: INTEGER
	chapter: INTEGER

	children: detachable ARRAYED_LIST [BIB_NAV_NODE]
			-- The node's children, once built. SW_TREE remembers what is open by object identity, so a
			-- node must hand out the same child objects every time (Larry, 2026-10-26: a book built anew
			-- on each expansion of its testament never stayed open).

	set_children (a_children: ARRAYED_LIST [BIB_NAV_NODE])
			-- Keep `a_children' as this node's children.
		do
			children := a_children
		ensure
			kept: children = a_children
		end

	is_testament: BOOLEAN
		do
			Result := first_book > 0
		end

	is_book: BOOLEAN
		do
			Result := book_id > 0 and chapter = 0
		end

	is_chapter: BOOLEAN
		do
			Result := chapter > 0
		end

invariant
	label_not_empty: not label.is_empty
	one_kind: (is_testament and not is_book and not is_chapter) or (not is_testament and (is_book xor is_chapter))

end
